
Read the CLAUDE.md file at the repo root to load all documentation 
patterns and rules.

Then read all 6 reference files from the EC2 module listed in CLAUDE.md 
to understand exact tone, formatting, depth, and structure.

Then generate the following 6 files for the module below, matching the 
reference files exactly:

**Module:**
- Name: $MODULE_NAME
- AWS Service: $AWS_SERVICE
- Path: $MODULE_PATH
- Purpose: $PURPOSE
- Terraform resources created: $RESOURCES
- Input variables: $VARIABLES
- Outputs: $OUTPUTS

**Files to create:**
1. `README.md` at module root
2. `docs/architecture.md`
3. `docs/design-decisions.md`
4. `docs/setup-guide.md`
5. `docs/troubleshooting.md`
6. `docs/interview-prep.md`

Write each file completely — no placeholders except the 
"Issues Faced During Implementation" section in troubleshooting.md 
which should be present but blank.
