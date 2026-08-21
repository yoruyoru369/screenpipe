---
schedule: manual
enabled: true
template: true
title: Time Breakdown
description: "Where your time went — by app, project, and category"
icon: "⏱"
featured: true
---


Analyze my app usage from today (last 12 hours). Read the screenpipe skill first. Use limit=10 per search, max 4 searches. For time per app, aggregate frames by app over the range using whatever screenpipe query tool you have (a COUNT/GROUP BY query or the activity summary). Use only screenpipe's recorded data, not this project's files or other apps' source.

Use this exact format with durations and percentages:

## By Application
- Each app with duration and percentage, sorted by time (e.g. "VS Code: 2h 15min (28%)").

## By Category
- Group into: coding, meetings, browsing, writing, communication, other. Show hours and % per category.

## By Project
- Group related activity by project/topic. Name specific repos or tasks.

## Focus Score
- focused / total as a percentage. Focused = coding + writing; unfocused = browsing + app-switching.

End with: "**Suggestion:** [one specific change to improve tomorrow]"
