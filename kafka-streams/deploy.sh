PROJECT=${PROJECT:-kafka-streams}
LOG_LEVEL=${LOG_LEVEL:-INFO}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

printf "\n\n######## $PROJECT/deploy ########\n"

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

oc process -f "${DIR}/common.yml" \
-p LOG_LEVEL="${LOG_LEVEL}" \
-p KAFKA_SVC_USERNAME="${KAFKA_SVC_USERNAME}" \
-p KAFKA_SVC_PASSWORD="${KAFKA_SVC_PASSWORD}" \
-p KAFKA_BOOTSTRAP_URL="${KAFKA_BOOTSTRAP_URL}" \
-p CLUSTER_NAME="${CLUSTER_NAME}" | oc create -f -

oc apply \
-f $DIR/matches-aggregator.is.yml \
-f $DIR/matches-aggregator.svc.yml \
-f $DIR/matches-aggregator.deployment.yml \
-f $DIR/matches-aggregator.route.yml

oc apply \
-f $DIR/player-aggregator.is.yml \
-f $DIR/player-aggregator.svc.yml \
-f $DIR/player-aggregator.deployment.yml \
-f $DIR/player-aggregator.route.yml

oc apply \
-f $DIR/trigger.match-start.yml \
-f $DIR/trigger.attack.yml \
-f $DIR/trigger.match-end.yml

kn service create event-forwarder \
--image "quay.io/redhatdemo/2021-kafka-event-forwarder-nodejs" \
-e NODE_ENV=$NODE_ENV \
-e CLUSTER_NAME=$CLUSTER_NAME \
-e KAFKA_SVC_USERNAME=$KAFKA_SVC_USERNAME \
-e KAFKA_SVC_PASSWORD=$KAFKA_SVC_PASSWORD \
-e KAFKA_BOOTSTRAP_URL=$KAFKA_BOOTSTRAP_URL \
-l app.openshift.io/runtime=nodejs
