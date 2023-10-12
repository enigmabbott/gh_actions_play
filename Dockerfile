FROM openjdk:17-alpine as jre-build

RUN apk add binutils

WORKDIR /code
COPY gradlew settings.gradle build.gradle /code/
COPY gradle/ /code/gradle
RUN ./gradlew --no-daemon build || exit 0

COPY src /code/src
RUN ./gradlew --no-daemon clean bootJar

RUN jar xf build/libs/spring-boot-0.0.1-SNAPSHOT.jar
RUN jdeps --ignore-missing-deps -q  \
    --recursive  \
    --multi-release 17  \
    --print-module-deps  \
    --class-path 'BOOT-INF/lib/*'  \
    build/libs/spring-boot-0.0.1-SNAPSHOT.jar > deps.info

RUN jlink \
    --add-modules $(cat deps.info) \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output /myjre

FROM alpine:latest
WORKDIR /deployment

ENV JAVA_HOME /user/java/jdk17
ENV PATH $JAVA_HOME/bin:$PATH

# copy the custom JRE produced from jlink
COPY --from=jre-build /myjre $JAVA_HOME

# copy the app
COPY --from=jre-build /code/build/libs/spring-boot-0.0.1-SNAPSHOT.jar app.jar

# run the app on startup
ENTRYPOINT java -jar app.jar

