FROM golang:1.18-alpine

WORKDIR /app

COPY . ./

RUN go mod download
RUN go build -o /goserver

EXPOSE 9000

CMD [ "/goserver" ]