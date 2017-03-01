# docset-publish

Packages a docset for Dash and publishes to S3

```yaml
deploy:
  steps:
    - sentia/docset-publish:
        docset: path/to/mydocset.docset
        bucket: my-docset-bucket/some/path
        aws_access_key_id: AKIAXXXXXXX
        aws_secret_access_key: XXXXXXXXX
```


### Step Properties:

**Docset** 

* `docset`: Path to the docset
* `bucket`: Name of the S3 bucket in which to publish the docset, you can also
  specify a path within the bucket as shown in the example
* `gemspec`: Get name and version from specified gemspec

**AWS Credentials**

* `aws_access_key_id`: Public part of the AWS credentials
* `aws_secret_access_key`: Private part of the AWS credentials
* `aws_session_token`: Session token, needed with temporary AWS credentials

These properties, if not specified, take a default value from following
environment variables in Wercker:
`$DOCSET_AWS_ACCESS_KEY_ID`,
`$DOCSET_AWS_SECRET_ACCESS_KEY`,
`$DOCSET_AWS_SESSION_TOKEN`