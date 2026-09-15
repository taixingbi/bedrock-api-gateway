# bedrock-api-gateway

The Bedrock Gateway platform's front door, split out of
`bedrock-gateway-infra`'s `modules/api_gateway` into its own repo (see
`plan.md` Section 25's repository structure). One HTTP API, one VPC
Link to the private ALB `bedrock-gateway-infra` manages, and two
routes reaching the same backend under different auth:

```text
ANY /iam/{proxy+}  AWS_IAM   -- SigV4-signed calls
ANY /{proxy+}      NONE      -- Bearer JWT calls, verified by the app itself
```

## Deliberately loose coupling to bedrock-gateway-infra

This repo never reads `bedrock-gateway-infra`'s Terraform state
(no `terraform_remote_state`, no hardcoded resource IDs). It looks up
the existing private ALB by name via a plain `data "aws_lb"` source
and creates its own VPC Link + security group
(`gateway-{env}-api-gw-vpc-link` — deliberately not reusing
`bedrock-gateway-infra`'s old `gateway-{env}-vpc-link` name, since AWS
enforces unique security group names per VPC and the old one still
existed during this split's cutover). Either repo can be re-applied
independently without needing the other's state file.

For `bedrock-gateway-infra`'s ALB security group to actually accept
traffic from this VPC Link, its `modules/ecs_service` ingress rule
looks this security group up by name too (`data "aws_security_group"`,
not a cross-state reference) — see that repo's own commit history for
the cutover.

## Why "destroy and recreate", not a state migration

The original `modules/api_gateway` resources in `bedrock-gateway-infra`
were destroyed and this repo's resources created fresh, rather than
migrating the existing Terraform state across repos
(`terraform state mv`/`import`). That means a new
`api_endpoint` (a new `*.execute-api.*.amazonaws.com` URL) — every
caller (the portal's `GATEWAY_API_URL`, any SigV4 client's endpoint
config) needed updating to match. Simpler to set up than a careful
state migration, at the cost of that one-time URL change.

## CI/CD

Same dev-auto/prod-manual-promotion shape as `bedrock-gateway-infra`:
push to `main` auto-applies `environments/dev`; `environments/prod` is
a separate `workflow_dispatch` (`promote-prod.yml`) pinned to a commit
SHA that already applied cleanly to dev, gated by a required-reviewer
GitHub Environment.
