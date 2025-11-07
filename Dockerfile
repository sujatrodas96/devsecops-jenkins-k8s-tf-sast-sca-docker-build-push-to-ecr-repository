FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY target/asgbuggy.jar /app/asgbuggy.jar

RUN mkdir -p /app/logs

ENTRYPOINT ["java", "-Xlog:gc*:file=/app/logs/gc.log", "-jar", "/app/asgbuggy.jar"]
