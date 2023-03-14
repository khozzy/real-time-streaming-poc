# Real-time Streaming PoC

I'm using [aws-vault](https://github.com/99designs/aws-vault) to store AWS connection profile named `personal-tf` that is used in this document.

## 1. Build Apache Flink app
You need to have JDK11 and Apache Maven tools installed to build the app JAR file.

```bash
# Build JAR natively
(cd my-kda-application && mvn clean package)

# Build JAR file using Docker container
(cd my-kda-application && ./build.sh)
```

## 2. Infrastructure provisioning
- Kinesis Data Stream
- Kinesis Streaming Application
- S3 Sink bucket

```bash
terraform init
aws-vault exec personal-tf -- terraform apply
```

## 3. Generate data
Python data generators reside in [/data-generators](/data-generators) folder.

```bash
pipenv install

# emit random temperature measurements to "stream_in" Kinesis data stream 
aws-vault exec personal-tf -- pipenv run gen_temp stream_in
```


## Resources
- https://docs.aws.amazon.com/kinesisanalytics/latest/java/get-started-exercise-fh.html
-  https://github.com/aws-samples/amazon-kinesis-data-analytics-examples/blob/master/FirehoseSink/src/main/java/com/amazonaws/services/kinesisanalytics/FirehoseSinkStreamingJob.java
