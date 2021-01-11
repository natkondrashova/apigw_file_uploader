# API-gw file uploader

### How to deploy
Ensure the values in `variables.tf` are correct, generate token for API-authentication(`myToken` for example) and just apply terraform:
```shell
terraform apply --var authorization_token=myToken
```

### How to test
You can find value of the `OUTPUT_BASE_URL`-variable in outputs as `base_url`. For your convince you can export it as an environment variable:
```shell
$ export OUTPUT_BASE_URL="{{ base_url }}"
```   

#### List objects in s3
```shell
curl $OUTPUT_BASE_URL/objects \
    -H "Authorization: myToken"
```

#### Put object:
```shell
curl $OUTPUT_BASE_URL/objects -X PUT \
    -H "Content-Type: application/json" -H "Authorization: myToken" \
    -d '{"Data":"new data2"}'
```
and wait about 5-10 minutes

#### Get object
```shell
curl $OUTPUT_BASE_URL/objects/{objectID} \
    -H "Authorization: myToken"
```
Do not forget to replace `/` to `%2F` in objectID.

#### Delete object
```shell
curl $OUTPUT_BASE_URL/objects/{objectID} -X DELETE \
    -H "Authorization: myToken"
```
Do not forget to replace `/` to `%2F` in objectID.


### Known issues
1. Authentication token is statically defined
2. Big delay from `terraform apply` to working service
3. Terraform state is not located in S3-bucket
4. Not optimal IAM-permissions in multiple places
