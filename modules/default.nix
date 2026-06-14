{ den, lib, inputs, ... }:
{
  den.policies.clan-lib-to-all = _: [
    (den.lib.policy.resolve {
      clanLib = inputs.clan-core.lib;
    })
  ];
  den.default.includes = [ den.policies.clan-lib-to-all ];
}
