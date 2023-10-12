FROM openjdk:17-alpine as jre-build

WORKDIR /code
COPY gradlew settings.gradle build.gradle /code/
COPY gradle/ /code/gradle
RUN ./gradlew build || exit 0

COPY src /code/src
RUN ./gradlew --no-daemon clean bootJar


FROM openjdk:17-alpine 
WORKDIR /deployment

# copy the app
COPY --from=jre-build /code/build/libs/spring-boot-0.0.1-SNAPSHOT.jar app.jar

# run the app on startup
ENTRYPOINT java -jar app.jar

