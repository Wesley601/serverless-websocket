const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require("@aws-sdk/client-apigatewaymanagementapi");

const clients = new Set();

const sendMessageToAllConnected = async (event) => {
  const endpoint = `https://${event.requestContext.domainName}/${event.requestContext.stage}`

  console.log({ endpoint });

  const client = new ApiGatewayManagementApiClient({
    apiVersion: "2018-11-29",
    endpoint,
  });

  const postCalls = Array.from(clients).map((clientId) =>
    client
      .send(new PostToConnectionCommand({ ConnectionId: clientId, Data: event.body }))
  );

  return Promise.all(postCalls);
};

const handler = async (event, context, callback) => {
  switch (event.requestContext.routeKey) {
    case "$connect":
      console.log("connect");
      clients.add(event.requestContext.connectionId);
      console.log(clients);
      break;
    case "$disconnect":
      console.log("disconnect");
      clients.delete(event.requestContext.connectionId);
      break;
    case "MESSAGE":
      console.log("MESSAGE");
      console.log(clients);
      await sendMessageToAllConnected(event);
      break;
    default:
      console.log("default");
      break;

  }

  return { statusCode: 200 };
};

exports.handler = handler;
