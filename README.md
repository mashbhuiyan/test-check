



## Getting Started

-   [Live link](https://api.insurance.io)
-   [Staging link](https://staging-api.insurance.io)

### Unit Testing
We have used [Mocha](https://mochajs.org) for unit testing.

#### Prerequisites of running unit tests
-  Run the following command to install the required packages:
```bash
npm install
```  
-  You need to create a database in PostgreSQL and set up the below environment variables in `.env` file. You can find the required environment variables in `.env.example` file. Also need to set up the MongoDB URI for the test database.
```bash
TEST_DB_USER=
TEST_DB_NAME=
TEST_DB_PASSWORD=
TEST_DB_HOST=
TEST_DB_PORT=
MONGODB_TEST_URI=
```
-  Import the database schema from `test/agent_portal_schema.sql` file to the database you have created. To import the schema, run the following command:
```bash
psql -U <db_user> <db_name> < test/agent_portal_schema.sql
```
### Running unit tests
To run the test cases, use the following command:
```bash
npm run test
```
Or you can run the test cases with mocha using the following command:
```bash
mocha --recursive --exit --timeout 10000
```
