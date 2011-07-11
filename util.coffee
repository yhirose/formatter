# **util.coffee** provides usefull functions, classes and so on.

#### **Number** class enhancement

# **times** method.  It repeats the given callback n times.
#
#     3.times ->
#       console.log 'hello world.'
#    
#     3.times (i) ->
#       console.log "hello world #{i}."
#
Number::times = (callback) ->
  callback i for i in [0...this]

