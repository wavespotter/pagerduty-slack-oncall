STACKNAME_BASE=pd-oncall-chat-topic
REGION="ca-central-1"
BUCKET=$(STACKNAME_BASE) # Bucket in REGION that is used for deployment (`pd-oncall-chat-topic` is already used)
SSMKeyArn=$(shell aws kms --region $(REGION) describe-key --key-id alias/aws/ssm --query KeyMetadata.Arn)
MD5=$(shell md5sum lambda/*.py | md5sum | cut -d ' ' -f 1)


deploy:
	cd lambda && \
		zip -r9 /tmp/deployment.zip *.py && \
		aws s3 cp --region $(REGION) /tmp/deployment.zip \
			s3://$(BUCKET)/$(MD5) && \
		rm -rf /tmp/deployment.zip
	aws cloudformation deploy \
		--template-file deployment.yml \
		--stack-name $(STACKNAME_BASE) \
		--region $(REGION) \
		--parameter-overrides \
		"Bucket=$(BUCKET)" \
		"md5=$(MD5)" \
		"SSMKeyArn"=$(SSMKeyArn) \
		"PDSSMKeyName"=$(STACKNAME_BASE) \
		"SlackSSMKeyName"=$(STACKNAME_BASE)-slack \
		--capabilities CAPABILITY_IAM || exit 0

discover:
	aws cloudformation --region $(REGION) \
		describe-stacks \
		--stack-name $(STACKNAME_BASE) \
		--query 'Stacks[0].Outputs'
