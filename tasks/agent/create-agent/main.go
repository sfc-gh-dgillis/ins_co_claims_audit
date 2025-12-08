package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/ast"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/errors"
	"cuelang.org/go/encoding/json"
	"github.com/kelseyhightower/envconfig"

	_ "embed"

	"github.com/gilcrest/graupel"
)

type Config struct {
	PAT              string `required:"true"`
	SnowflakeBaseURL string `required:"true"`
}

const applicationName = "graupel"

// Embed our schema in a Go string variable.
//
//go:embed schema.cue
var cueSource string

func main() {
	var c Config

	err := envconfig.Process(applicationName, &c)
	if err != nil {
		log.Fatal(err.Error())
	}

	// Create a Snowflake Cortex client
	var client *graupel.Client
	client, err = graupel.NewClient(nil).
		WithProgrammaticAccessToken(c.PAT).
		WithSnowflakeBaseURL(c.SnowflakeBaseURL)
	if err != nil {
		log.Fatal(err)
	}

	ctx := context.Background()

	var agent *graupel.CortexAgent
	//agent = makeAgent()

	agent, err = makeAgentViaJSON()
	if err != nil {
		// Extract one or more errors from the evaluation.
		errs := errors.Errors(err)

		// Display information about the errors.
		fmt.Println(`# Error summary [err]:`)
		fmt.Printf("%v\n\n", err)

		fmt.Println(`# Error details [errors.Details(err)]:`)
		fmt.Printf("%v\n", errors.Details(err, nil))

		fmt.Println(`# Error count [len(errs)]:`)
		fmt.Printf("%d\n", len(errs))
		log.Fatal(err)
	}

	// List all Cortex Agents
	var (
		cr   *graupel.CreateResponse
		resp *graupel.Response
	)
	cr, resp, err = client.Agents.Create(ctx, agent, &graupel.CreateOptions{CreateMode: graupel.CreateModeOrReplace})
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("HTTP Response Status: %+v\n", resp.Response.Status)
	fmt.Printf("Response Body Status: %+v\n", cr.Status)
}

func makeAgent() *graupel.CortexAgent {
	return &graupel.CortexAgent{
		Owner:         graupel.Ptr("dgillis"),
		DatabaseName:  graupel.Ptr("ins_co"),
		SchemaName:    graupel.Ptr("loss_claims"),
		Name:          graupel.Ptr("test"),
		Comment:       graupel.Ptr("test comment on create"),
		Profile:       &graupel.AgentProfile{DisplayName: graupel.Ptr("test display name on create")},
		Models:        &graupel.ModelConfig{Orchestration: graupel.Ptr("test orchestration")},
		Instructions:  nil,
		Orchestration: nil,
		Tools:         nil,
		ToolResources: nil,
		AgentSpecStr:  nil,
		CreatedOn:     time.Time{},
	}
}

func makeAgentViaJSON() (*graupel.CortexAgent, error) {
	ctx := cuecontext.New()

	// Build the schema
	schema := ctx.CompileString(cueSource).LookupPath(cue.ParsePath("#CortexAgent"))

	// Load the JSON file specified (the program's sole argument) as a CUE value
	dataFilename := os.Args[1]
	dataFile, err := os.ReadFile(dataFilename)
	if err != nil {
		log.Fatal(err)
	}

	var dataExpr ast.Expr
	dataExpr, err = json.Extract(dataFilename, dataFile)
	if err != nil {
		return nil, err
	}

	// Build the CUE value from the JSON data
	v := ctx.BuildExpr(dataExpr)

	// Validate the JSON data using the schema
	uv := schema.Unify(v)
	if err := uv.Validate(); err != nil {
		return nil, err
	}

	var cr *graupel.CreateRequest
	err = uv.Decode(&cr)
	if err != nil {
		log.Fatal(err)
	}

	var der map[string]graupel.ToolResource
	der, err = graupel.ParseToolResources(cr.ToolResources, cr.Tools)
	if err != nil {
		return nil, err
	}

	agent := &graupel.CortexAgent{
		DatabaseName:  cr.DatabaseName,
		SchemaName:    cr.SchemaName,
		Name:          cr.Name,
		Comment:       cr.Comment,
		Profile:       cr.Profile,
		Models:        cr.Models,
		Instructions:  cr.Instructions,
		Orchestration: cr.Orchestration,
		Tools:         cr.Tools,
		ToolResources: der,
	}

	fmt.Printf("Cortex Agent: %+v\n", agent)

	return agent, nil
}

func makeAgentViaYAML() *graupel.CortexAgent {
	return new(graupel.CortexAgent)
}

//type authTransport struct {
//	Transport http.RoundTripper
//	Token     string
//}
//
//func (t *authTransport) RoundTrip(req *http.Request) (*http.Response, error) {
//	req = req.Clone(req.Context())
//	req.Header.Set("Authorization", "Bearer "+t.Token)
//	return t.Transport.RoundTrip(req)
//}
