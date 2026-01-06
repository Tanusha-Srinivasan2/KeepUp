# Multi-stage build for Spring Boot app
# Stage 1: Build the application
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy only pom.xml first (cache dependencies layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime image (slim JRE)
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Create the secrets directory (will be empty in the image)
RUN mkdir -p /app/secrets

# Copy the built jar from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose the port your Spring Boot app runs on
EXPOSE 8080

# Run the application
# The service-account.json will be mounted at runtime into /app/secrets/
ENTRYPOINT ["java", "-jar", "app.jar"]
