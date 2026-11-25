
- source_plan: `plan-verified-default-home.md`
  summary: System HOME intent resumes the current Flutter settings/drawer route instead of the goal Home screen; implement immediately next.
  evidence: API36 real system Home from Android Settings returned to Fitrah Settings after successful ROLE_HOME selection; existing MainActivity has no HOME intent navigation bridge.

- source_plan: `plan-system-home-navigation.md`
  summary: Resolved the preceding system HOME navigation issue.
  evidence: VersionCode14 real system Home from Android Settings and launched Android Clock both returned to central goal Home with the retained QA goal on API36.
