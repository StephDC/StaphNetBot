# StaphNetBot
A TG Network looking glass bot

## Usage

Put your bot API into `botapi.sh`, then:

```
./StaphNet.sh
```

## Note
Please do not accidentally commit your modifications in `botapi.sh`.

The following command can help you avoid it:

```
git update-index --assume-unchanged botapi.sh
```

Also I have no responsibility to the security of this bot.

There is the potential risk for someone to use telegram chat to your bot to run arbitrary code on your host.
Do whatever you can to mitigate this risk.
