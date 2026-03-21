import { describe, expect, it } from "vitest";
import { withEnvAsync } from "../test-utils/env.js";
import { getFreePort, installGatewayTestHooks, startGatewayServer } from "./test-helpers.js";

installGatewayTestHooks({ scope: "suite" });

describe("gateway startup runtime env overrides", () => {
  it("allows non-loopback Control UI fallback from env without a config file", async () => {
    await withEnvAsync(
      {
        OPENCLAW_CONTROL_UI_FALLBACK: "true",
        OPENCLAW_GATEWAY_MODE: "local",
      },
      async () => {
        const port = await getFreePort();
        const server = await startGatewayServer(port, {
          bind: "lan",
          controlUiEnabled: true,
        });
        try {
          expect(server).toBeDefined();
        } finally {
          await server.close();
        }
      },
    );
  });
});
