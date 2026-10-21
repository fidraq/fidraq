package membership

import "github.com/fidraq/fidraq/khazina/internal/store"

func mapEnvironmentFromStore(env store.ProjectEnvironment) ProjectEnvironment {
	switch env {
	case store.ProjectEnvironmentSandbox:
		return EnvironmentSandbox
	case store.ProjectEnvironmentProduction:
		return EnvironmentProduction
	default:
		return EnvironmentUnknown
	}
}
