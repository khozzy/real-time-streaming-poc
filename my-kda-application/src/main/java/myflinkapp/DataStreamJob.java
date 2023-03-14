// https://github.com/aws-samples/amazon-kinesis-data-analytics-examples/blob/master/GettingStarted_1_13/src/main/java/com/amazonaws/services/kinesisanalytics/BasicStreamingJob.java
// https://docs.aws.amazon.com/kinesisanalytics/latest/java/how-properties.html
package myflinkapp;

import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.typeutils.AvroUtils;
import org.apache.flink.formats.parquet.avro.AvroParquetWriters;
import org.apache.flink.connector.firehose.sink.KinesisFirehoseSink;
import org.apache.flink.core.fs.Path;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.JsonNode;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.OutputFileConfig;
import org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink;
import org.apache.flink.streaming.api.functions.sink.filesystem.bucketassigners.DateTimeBucketAssigner;
import org.apache.flink.streaming.api.windowing.assigners.SlidingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.connectors.kinesis.FlinkKinesisConsumer;
import org.apache.flink.streaming.connectors.kinesis.config.ConsumerConfigConstants;

import java.io.IOException;
import java.util.Map;
import java.util.Properties;


/**
 * A basic Kinesis Data Analytics for Java application with Kinesis data
 * streams as source and sink.
 */
public class DataStreamJob {
    private static final ObjectMapper jsonParser = new ObjectMapper();
    private static final String region = "eu-central-1";
    private static final String inputStreamName = "stream_in";
    private static final String outputDeliveryStreamName = "stream_out";

    private static final String s3SinkPath = "s3://khozzy-data-streaming";

    private static DataStream<String> createSourceFromStaticConfig(StreamExecutionEnvironment env) {
        Properties inputProperties = new Properties();
        inputProperties.setProperty(ConsumerConfigConstants.AWS_REGION, region);
        inputProperties.setProperty(ConsumerConfigConstants.STREAM_INITIAL_POSITION, "LATEST");

        return env.addSource(new FlinkKinesisConsumer<>(inputStreamName, new SimpleStringSchema(), inputProperties));
    }

    private static DataStream<String> createSourceFromApplicationProperties(StreamExecutionEnvironment env) throws IOException {
        Map<String, Properties> applicationProperties = KinesisAnalyticsRuntime.getApplicationProperties();
        return env.addSource(new FlinkKinesisConsumer<>(inputStreamName, new SimpleStringSchema(),
                applicationProperties.get("ConsumerConfigProperties")));
    }

    private static StreamingFileSink<TemperatureMeasurement> createS3SinkFromStaticConfig() {
        return StreamingFileSink
                .forBulkFormat(new Path(s3SinkPath), AvroParquetWriters.forReflectRecord(TemperatureMeasurement.class))
                .withBucketAssigner(new DateTimeBucketAssigner<>("'year='yyyy'/month='MM'/day='dd'/hour='HH/"))
                .withOutputFileConfig(OutputFileConfig.builder()
                        .withPartSuffix(".parquet")
                        .build())
                .build();
    }

//    private static FlinkKinesisProducer<String> createSinkFromStaticConfig() {
//        Properties outputProperties = new Properties();
//        outputProperties.setProperty(ConsumerConfigConstants.AWS_REGION, region);
//        outputProperties.setProperty("AggregationEnabled", "false");
//
//        FlinkKinesisProducer<String> sink = new FlinkKinesisProducer<>(new SimpleStringSchema(), outputProperties);
//        sink.setDefaultStream(outputStreamName);
//        sink.setDefaultPartition("0");
//        return sink;
//    }

//    private static FlinkKinesisProducer<String> createSinkFromApplicationProperties() throws IOException {
//        Map<String, Properties> applicationProperties = KinesisAnalyticsRuntime.getApplicationProperties();
//        FlinkKinesisProducer<String> sink = new FlinkKinesisProducer<>(new SimpleStringSchema(),
//                applicationProperties.get("ProducerConfigProperties"));
//
//        sink.setDefaultStream(outputStreamName);
//        sink.setDefaultPartition("0");
//        return sink;
//    }

//    private static KinesisFirehoseSink<String> createFirehoseSinkFromStaticConfig() {
//        Properties sinkProperties = new Properties();
//        sinkProperties.setProperty(ConsumerConfigConstants.AWS_REGION, region);
//
//        return KinesisFirehoseSink.<String>builder()
//                .setFirehoseClientProperties(sinkProperties)
//                .setSerializationSchema(new SimpleStringSchema())
//                .setDeliveryStreamName(outputDeliveryStreamName)
//                .build();
//    }


    public static void main(String[] args) throws Exception {
        // set up the streaming execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        /* if you would like to use runtime configuration properties, uncomment the lines below
         * DataStream<String> input = createSourceFromApplicationProperties(env);
         */
        DataStream<String> input = createSourceFromStaticConfig(env);
        System.out.println("Created source from static conf");

        /* if you would like to use runtime configuration properties, uncomment the lines below
         * input.addSink(createSinkFromApplicationProperties())
         */

        input.map(value -> { // Parse the JSON
                    JsonNode jsonNode = jsonParser.readValue(value, JsonNode.class);
                    return new Tuple2<>(jsonNode.get("status").asText(),
                            jsonNode.get("current_temperature").asDouble());
                }).returns(Types.TUPLE(Types.STRING, Types.DOUBLE))
                .keyBy(v -> v.f0)
                .window(SlidingProcessingTimeWindows.of(Time.seconds(10), Time.seconds(5)))
                .min(1)
                .map(v -> new TemperatureMeasurement(v.f0, v.f1))
                .addSink(createS3SinkFromStaticConfig())
                .name("S3 sink");

        env.execute("Flink s3 streaming app");
    }
}

