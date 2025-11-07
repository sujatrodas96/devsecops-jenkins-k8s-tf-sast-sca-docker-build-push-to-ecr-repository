# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /usr/src/easybuggy
COPY . .

RUN mvn -B clean package

# ---- Runtime stage ----
FROM eclipse-temurin:17-jdk

WORKDIR /app

# Copy JAR from builder
COPY --from=builder /usr/src/easybuggy/target/easybuggy.jar /app/easybuggy.jar

# Create logs directory
RUN mkdir -p /app/logs

# Valid JSON array syntax for ENTRYPOINT
ENTRYPOINT ["java","-Xmx256m", "-XX:MaxMetaspaceSize=128m", "-XX:MaxDirectMemorySize=90m", "-Xlog:gc*,gc+heap=debug:file=/app/logs/gc.log:time,uptime,level,tags:filecount=5,filesize=10M", "-XX:GCTimeLimit=15", "-XX:GCHeapFreeLimit=50", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:HeapDumpPath=/app/logs/", "-XX:ErrorFile=/app/logs/hs_err_pid%p.log", "-agentlib:jdwp=transport=dt_socket,server=y,address=9009,suspend=n", "-Dderby.stream.error.file=/app/logs/derby.log", "-Dderby.infolog.append=true", "-Dderby.language.logStatementText=true", "-Dderby.locks.deadlockTrace=true", "-Dderby.locks.monitor=true", "-Dderby.storage.rowLocking=true", "-Dcom.sun.management.jmxremote", "-Dcom.sun.management.jmxremote.port=7900", "-Dcom.sun.management.jmxremote.ssl=false", "-Dcom.sun.management.jmxremote.authenticate=false", "-ea", "-jar", "/app/easybuggy.jar"]
