#Here we use multi-stage build to minimize size of the final image.
#Download go-auto-yt via git and youtube-dl via curl on ubuntu temp image
FROM ubuntu as DOWNLOAD
WORKDIR /git
RUN apt-get update && apt-get install git curl -y 
RUN curl -L https://yt-dl.org/downloads/latest/youtube-dl -o ./youtube-dl && chmod a+rx ./youtube-dl
RUN git clone https://github.com/XiovV/go-auto-yt.git
RUN cd go-auto-yt
RUN if [ ${TRAVIS_PULL REQUEST} != false ] ; then git fetch origin +refs/pull/${TRAVIS_PULL REQUEST}/merge && git checkout FETCH_HEAD ; fi

#Transfer git content from DOWNLOAD stage over GO stage to build application
FROM golang:alpine as GO
WORKDIR /app
COPY --from=DOWNLOAD /git/go-auto-yt .
RUN go build -o main .

#Use ffmpeg as base image and copy executable from other temp images
FROM jrottenberg/ffmpeg:alpine as BASE
WORKDIR /app
COPY --from=GO /app/main .
COPY --from=GO /app/static ./static
COPY --from=GO /app/entrypoint.sh .
COPY --from=DOWNLOAD /git/youtube-dl /usr/local/bin/
RUN apk --update add python shadow
RUN addgroup -S goautoyt
RUN adduser --system goautoyt --ingroup goautoyt 

#Set starting command
ENTRYPOINT ["./entrypoint.sh"]

#Expose port and volumes
EXPOSE 8080
VOLUME /app/downloads
VOLUME /app/config
