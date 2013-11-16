###
// ==UserScript==
// @name Xujc Teach File System CAPTCH
// @namespace  http://mutoo.im/
// @version 1.0
// @description auto recognize the verify code
// @match      http://teach.xujc.com/*
// @match      http://teach.xujc.cn/*
// @require    http://code.jquery.com/jquery-latest.js
// @updateURL
// ==/UserScript==
###

sigmoidTransfer = (value) ->
    1/(1+Math.exp(-value))

# arc to connect nodes
class Arc
    constructor: (weight) ->
        @weight = weight? Math.random(2)-1
    update: (@weight) ->
    setInputNode: (@inputNode) ->
    setOutputNode: (@outputNode) ->
    getWeightedInput: () ->
        @inputNode.value * @weight

# abstract node
class Node
    constructor: (value) ->
        @value = value ? 0
        @inputArcs = []
        @outputArcs = []
        # ...
    connectNode: (node) ->
        @connectNodeWithArc(new Arc, node)
    connectNodeWithArc: (arc, node) ->
        arc.setInputNode @
        arc.setOutputNode node
        node.addInputArc arc
        @addOutputArc arc
        return
    addInputArc: (arc) ->
        @inputArcs.push arc
    addOutputArc: (arc) ->
        @outputArcs.push arc
    update: () ->
        result = 0
        for arc in @inputArcs
            result += arc.getWeightedInput()
            # ...
        @value = sigmoidTransfer result

class InputNode extends Node
    constructor: (value) ->
        super value

    update: (@value) ->

class HiddenNode extends Node
    constructor: () ->
        super()

class OutputNode extends Node
    constructor: () ->
        super()

# simple ann for calculation 
class Net
    constructor: (@numOfInputs, @numOfHiddens, @numOfOutputs) ->
        @buildNet()

    buildNet: () ->
        @inputNodes = []
        @hiddenNodes = []
        @outputNodes = []
        
        # input layer
        @inputNodes.push(new InputNode) for i in [1..@numOfInputs]
        @inputNodes.push(new InputNode -1)

        # hidden layer
        @hiddenNodes.push(new HiddenNode) for i in [1..@numOfHiddens]
        @hiddenNodes.push(new InputNode -1)

        # output layer
        @outputNodes.push(new OutputNode) for i in [1..@numOfOutputs]

        # connect input layer to hidden layer
        for inputNode in @inputNodes
            for i in [0...@numOfHiddens]
                inputNode.connectNode @hiddenNodes[i]

        # connect hidden layer to output layer
        for hiddenNode in @hiddenNodes
            for outputNode in @outputNodes
                hiddenNode.connectNode outputNode
        
        return

    load: (data) ->
        point = 0;
        for inputNode in @inputNodes
            for arc in inputNode.outputArcs
                arc.update data[point++]

        for hiddenNode in @hiddenNodes
            for arc in hiddenNode.outputArcs
                arc.update data[point++]

    run: (inputs) ->
        throw "wrong number of inputs" if inputs.length != @numOfInputs
        for i in [0...@numOfInputs]
            @inputNodes[i].update inputs[i]

        for i in [0...@numOfHiddens]
            @hiddenNodes[i].update()
        
        for outputNode in @outputNodes
            outputNode.update()

# create net with specified agruments        
Net.create = (numOfInputs, numOfHiddens, numOfOutputs) ->
    return new Net(numOfInputs, numOfHiddens, numOfOutputs)

# create net with weights data
Net.createWithData = (data) ->
    point = 0
    numOfInputs = data[point++]
    numOfHiddens = data[point++]
    numOfOutputs = data[point++]
    net = new Net(numOfInputs, numOfHiddens, numOfOutputs)
    net.load data[3..]
    return net

data = [
    18, # numOfInputs
    3,  # numOfHiddens
    26, # numOfOutputs
    4.470576,2.7355769,-6.5390086,-13.101406,-5.9211597,6.667446,9.22045,5.2305045,-3.4738727,-4.7141204,12.937106,-4.6152735,4.621963,-18.154024,1.5861913,1.7433782,-9.3908205,-3.4764493,-8.704641,-1.9202846,0.7354568,3.6340122,5.748247,5.636461,13.02596,2.0759354,-10.997512,-0.6902169,4.8752866,-23.330648,0.7211854,-9.06602,4.532581,-8.392522,-6.002599,13.928483,12.361175,16.01484,8.387604,-4.2942247,-1.6765488,13.035718,6.4948993,-3.47155,-10.260907,7.961886,-6.131321,-2.622574,-4.488799,-8.651039,8.874655,-21.977839,0.4411778,-5.0922227,-7.1307387,-7.5753045,-3.6616912,-10.373778,30.547338,0.81036043,8.443948,27.203302,-23.769861,16.727873,-12.419982,16.993464,5.292304,11.594804,-1.1777647,-2.228593,-26.839905,-45.538723,-11.65957,15.827081,7.909621,-1.0737777,-33.409515,16.233444,-1.7445779,-43.29539,-16.988482,-13.311783,-9.079687,-8.782504,-11.85278,-37.20242,-11.251744,-12.368148,13.499519,2.752592,27.085585,2.0348134,-42.859417,20.247005,-3.0802624,-0.29604116,-10.368679,7.4814277,-39.947617,-42.293667,-11.858528,23.27455,-4.1166687,20.538832,24.490065,-14.808113,10.000519,-18.431803,-28.147999,-40.68395,-11.115686,-21.371428,29.165455,8.255461,10.391819,-32.657097,-3.2285986,20.580618,13.14405,7.7376523,7.8338003,12.926984,20.6577,-5.860448,4.406302,-3.402267,-41.755882,14.001027,-18.048203,-8.207912,-26.153135,-0.77600145,-29.4237,-10.8358965,24.803003,-7.5253325,24.592216,-4.272933,31.007652,29.060694,18.152813,16.453743,21.932446,35.898216,11.555321,35.4501,7.866686,13.871775,14.064404,1.5232842,-1.2746866,10.479545,1.8933352,34.733418,-7.8495693,33.48177,20.721031,-5.150589,1.1920105,-6.9500947,15.963367, #weights
    1.4481915   # error
]

net = Net.createWithData(data)

IMG_WIDTH = 50
IMG_HEIGHT = 18

CHAR_WIDTH = 8
CHAR_HEIGHT = 10

threshold = (r,g,b) ->
    return ((r>>2)+(g>>1)+(b>>2))>200

parseResult = (result) ->
    max = -1
    flag = -1
    for i in [0...result.length]
        if result[i]>max
            max = result[i]
            flag = i
    return String.fromCharCode(65+(26-flag-1))

decode = (img) ->
    canvas = document.createElement("canvas")
    canvas.width = IMG_WIDTH
    canvas.height = IMG_HEIGHT
    ctx = canvas.getContext("2d")
    ctx.drawImage(img,0,0)

    code = ""

    for i in [0..3]
        feature = (0 for x in [0...CHAR_WIDTH+CHAR_HEIGHT])
        char = ctx.getImageData(3+i*12, 4, CHAR_WIDTH, CHAR_HEIGHT)
        for p in [0...CHAR_WIDTH*CHAR_HEIGHT*4] by 4
            if threshold(char.data[p+0],char.data[p+1],char.data[p+2])
                feature[(p/4>>0)%CHAR_WIDTH]++
                feature[CHAR_WIDTH+(p/4>>0)/CHAR_WIDTH>>0]++
        result = net.run(x/CHAR_HEIGHT for x in feature)
        code += parseResult(result)
    
    console.log(code)
    return code

$(() ->
    $('input[name="code"]').focus(() ->
        console.log("search <img src='image.php'> ...")
        console.log($('img[src="image.php"]'))
        img = $('img[src="image.php"]').get(0)
        if img.complete
           $(this).val decode(img)
    )
)