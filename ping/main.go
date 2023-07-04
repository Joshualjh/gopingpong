package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

func main() {
	for true {
		resp, err := http.Get("http://20.39.196.189:9000/ping")
		if err != nil {
			panic(err)
		}

		data, err := ioutil.ReadAll(resp.Body)
		fmt.Println(string(data))
		time.Sleep(1000 * time.Millisecond)
	}

}
