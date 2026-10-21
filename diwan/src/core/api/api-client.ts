import { createConnectTransport, type ConnectTransportOptions } from "@connectrpc/connect-web"
import { QueryClient } from "@tanstack/react-query";
import { authInterceptor } from "./auth-interceptor";
import { createClient } from "@connectrpc/connect";
import { AuthService } from "../../gen/fidraq/dashboard/auth/v1/auth_pb";

declare global {
  interface Window {
    __FIDRAQ_CONFIG__?: { apiUrl?: string };
  }
}

// Production sets apiUrl at container start (public/config.js, Caddyfile);
// dev falls back to VITE_API_URL from mise.toml.
const apiUrl = window.__FIDRAQ_CONFIG__?.apiUrl || import.meta.env.VITE_API_URL;
if (!apiUrl) {
  throw new Error("API URL is not configured: set API_URL (prod) or VITE_API_URL (dev)");
}

const baseTransportOpts: ConnectTransportOptions = {
  baseUrl: apiUrl,
};

const nakedTransport = createConnectTransport(baseTransportOpts)
export const refreshClient = createClient(AuthService, nakedTransport);


export const transport = createConnectTransport({
  ...baseTransportOpts,
  interceptors: [authInterceptor],
});

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 1000 * 5 * 60
    },
  },
});
