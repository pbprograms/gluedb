#Gluedb
*This document is intended for the internal development team.*

##Setup

###Setup the Rails Project
```
git clone https://github.com/dchbx/gluedb.git
cd gluedb
bundle install
```

###Setup Flat-UI
We need Nodejs and Bower
```
brew install node
npm install bower -g (this is needed to build flat-ui)
```

Get a copy of fuip-dev-1.3.0 (ask a team member)

```
cd fuip-dev-1.3.0/HTML/UI/
bower install
```

###Setup Mongodb
```
brew install mongodb
```

Start Mongodb Daemon
```
mongod
```

Get the mongodb dump (ask a team member). Go to the directory where the dump director resides (i.e. one level above dump directory).
```
mongorestore
```

