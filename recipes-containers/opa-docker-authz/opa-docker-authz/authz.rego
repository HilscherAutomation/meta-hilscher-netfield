package docker.authz

default allow = false

# allow all for root
allow {
    local_auth

    input.User == "root"
}

# Allow readonly if user is part of docker-readonly group
allow {
    local_auth

    groups := split(input.Headers["Authz-Groups"], ",")

    input.Method == "GET"
    contains(groups, "docker-readonly")
}

# Allow r/w if user is part of docker group and not part of docker-readonly
allow {
    local_auth

    groups := split(input.Headers["Authz-Groups"], ",")

    contains(groups, "docker")
    not contains(groups, "docker-readonly")
}

local_auth {
    auth_method := input.AuthMethod
    auth_method == "local"
}

contains(arr, elem) {
    arr[_] = elem
}
