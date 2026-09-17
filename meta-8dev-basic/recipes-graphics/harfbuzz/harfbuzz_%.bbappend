# Drop ICU integration; the built-in shaper covers our needs and avoids ~34M libicudata.
PACKAGECONFIG:remove:8dev-basic = "icu"
