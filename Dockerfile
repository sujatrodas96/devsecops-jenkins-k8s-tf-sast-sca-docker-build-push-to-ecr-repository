# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /usr/src/easybuggy
COPY . .

# Build WAR
RUN mvn clean package -DskipTests

# ---- Runtime stage ----
FROM tomcat:9.0-jdk17

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR built by Maven
COPY --from=builder /usr/src/easybuggy/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
