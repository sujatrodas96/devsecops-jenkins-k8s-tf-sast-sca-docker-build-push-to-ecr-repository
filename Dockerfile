# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /usr/src/easybuggy

# Copy source files
COPY . .

# Build WAR with clean
RUN mvn clean package -DskipTests

# ---- Runtime stage ----
FROM tomcat:9.0-jdk17

# Remove default webapps and work directory (compiled JSPs cache)
RUN rm -rf /usr/local/tomcat/webapps/* && \
    rm -rf /usr/local/tomcat/work/*

# Copy WAR built by Maven
COPY --from=builder /usr/src/easybuggy/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]