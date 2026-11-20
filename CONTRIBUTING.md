# Contributing

Thanks for helping out! SysMon is intentionally small — please keep it that way.

## Getting started

```bash
git clone https://github.com/ozkurtomer/sysmon.git
cd sysmon
./scripts/build.sh && open build/SysMon.app
```

Requires macOS 13+ and the Xcode Command Line Tools.

## Guidelines

- **Keep it dependency-free.** Apple frameworks only.
- **Stay light.** The app should use close to 0% CPU itself.
- **One concern per PR**, with a short description of what changed and why.
- If you change the menu layout, regenerate the README animation:
  `pip install pillow && python3 assets/make_demo_gif.py`

## Reporting bugs

Open an issue with your macOS version, Mac model (Apple Silicon / Intel), and what you expected vs. what happened.
