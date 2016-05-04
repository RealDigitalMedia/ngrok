// +build release

package client

var (
	rootCrtPaths = []string{"assets/client/tls/ngrokroot.crt",
		"assets/client/tls/letsencrypt.crt",
		"assets/client/tls/startcom.crt",
	}
)

func useInsecureSkipVerify() bool {
	return false
}
