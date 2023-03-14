# Real-time Streaming PoC

I'm using [aws-vault](https://github.com/99designs/aws-vault) to store AWS connection profile named `personal-tf` that is used in this document.

## Infrastructure
- Kinesis Data Stream
- Kinesis Streaming Application
- S3 Sink bucket

## Data generators
Python data generators reside in [/data-generators](/data-generators) folder.

```bash
pipenv install

# emit random temperature measurements to "stream_in" Kinesis data stream 
aws-vault exec personal-tf -- pipenv run gen_temp stream_in
```
