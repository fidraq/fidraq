package projectv1

import (
	"github.com/fidraq/fidraq/khazina/internal/app/gateway"
	projectpbv1 "github.com/fidraq/fidraq/khazina/internal/transport/proto/fidraq/dashboard/project/v1"
)

func mapConnectorType(ct gateway.ConnectorType) projectpbv1.Gateway_ConnectorType {
	switch ct {
	case gateway.ConnectorTypeMPGS:
		return projectpbv1.Gateway_CONNECTOR_TYPE_MPGS
	default:
		return projectpbv1.Gateway_CONNECTOR_TYPE_UNSPECIFIED
	}
}
