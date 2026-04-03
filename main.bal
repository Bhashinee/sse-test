import ballerina/http;
import ballerina/lang.runtime;
import ballerina/time;

listener http:Listener httpListener = new (9090);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowHeaders: ["Test-Key", "Content-Type"],
        allowMethods: ["GET", "OPTIONS"]
    }
}
service / on httpListener {

    resource function get events() returns http:Response {
        http:Response response = new;
        stream<http:SseEvent, error?> eventStream = new (new SseGenerator());
        response.setSseEventStream(eventStream);
        response.setHeader("X-Accel-Buffering", "no");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Headers", "Test-Key, Content-Type");
        return response;
    }
}

isolated class SseGenerator {
    private int count = 0;

    public isolated function next() returns record {|http:SseEvent value;|}|error? {
        runtime:sleep(1);
        int currentCount;
        lock {
            self.count += 1;
            currentCount = self.count;
        }
        time:Utc now = time:utcNow();
        string timestamp = time:utcToString(now);
        return {
            value: {
                id: currentCount.toString(),
                data: string `{"count":${currentCount},"time":"${timestamp}"}`
            }
        };
    }
}
