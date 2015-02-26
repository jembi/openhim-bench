conn = new Mongo();
db = conn.getDB("openhim-bench");
db.dropDatabase();

db.clients.insert(
    {
        "clientID": "bench",
        "name": "OpenHIM Benchmark Client",
        "clientDomain": "openhim.org",
        "passwordAlgorithm": "sha512",
        "passwordHash": "8b4533ba40c612ebf863aec1ce72ce0d20f8d0a3fedfa8cba0f3dc18dd31f01eee3e17c0f85acc1c8b8c4d153d4a8e15d1ba01793a6b5579f6d5b8ea3e113905",
        "passwordSalt": "b9447dac3f389328ad08224c9ad4242f",
        "roles": [
            "xds",
            "bench"
        ]
    }
);

db.channels.insert(
    {
        "alerts": [],
        "allow": [
            "bench"
        ],
        "authType": "private",
        "description": "OpenHIM Bench - Basic GET Test",
        "matchContentJson": null,
        "matchContentRegex": null,
        "matchContentTypes": [],
        "matchContentValue": null,
        "matchContentXpath": null,
        "name": "OpenHIM Bench - Basic GET Test",
        "pollingSchedule": null,
        "properties": [],
        "requestBody": true,
        "responseBody": true,
        "routes": [
            {
                "host": "localhost",
                "name": "Basic GET",
                "port": 6050,
                "primary": true,
                "secured": false,
                "type": "http",
            }
        ],
        "status": "enabled",
        "tcpHost": null,
        "tcpPort": null,
        "txRerunAcl": [],
        "txViewAcl": [],
        "txViewFullAcl": [],
        "type": "http",
        "urlPattern": "^/bench/basic/get$",
        "whitelist": []
    }
);
db.channels.insert(
    {
        "alerts": [],
        "allow": [
            "bench"
        ],
        "authType": "private",
        "description": "OpenHIM Bench - Basic POST Test",
        "matchContentJson": null,
        "matchContentRegex": null,
        "matchContentTypes": [],
        "matchContentValue": null,
        "matchContentXpath": null,
        "name": "OpenHIM Bench - Basic POST Test",
        "pollingSchedule": null,
        "properties": [],
        "requestBody": true,
        "responseBody": true,
        "routes": [
            {
                "host": "localhost",
                "name": "Basic POST",
                "port": 6050,
                "primary": true,
                "secured": false,
                "type": "http",
            }
        ],
        "status": "enabled",
        "tcpHost": null,
        "tcpPort": null,
        "txRerunAcl": [],
        "txViewAcl": [],
        "txViewFullAcl": [],
        "type": "http",
        "urlPattern": "^/bench/basic/post$",
        "whitelist": []
    }
);
