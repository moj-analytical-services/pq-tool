var log = true;
var points;
var point_centres = [];
var last_mouse_location = [0,0];
var selected_rank = -1;

//Table-clicking function

function format(d) {
    console.log(d);
    d[3] = d[3].replace(/&lt;(.+?)&gt;/g, '<' + '$1' + '>');
    return '<div style=\"background-color:#eee; padding: .5em;word-wrap:break-word;width: 600px; \"> Question Text: ' +
                d[2] + '</br>' + '</br>' +
                'Answer Text: ' + d[3] +  '</div>' +
                '<input type = \"button\" value = \"See all questions asked by this Member\" onclick = \"mp_finder(\'' + d[6] + '\')\">' + 
                '<input type = \"button\" value = \"See all questions in the same topic\" onclick = \"topic_finder(' + d[9] + ')\">';
}
var table1;
function rowActivate() {
    var row = this.closest('tr');
    var showHideIcon = $(row.firstChild);
    var shinyRow = table1.row(row);
    if (shinyRow.child.isShown()) {
        shinyRow.child.hide();
        showHideIcon.html('&oplus;');
    } else {
        shinyRow.child(format(shinyRow.data())).show();
        showHideIcon.html('&ominus;');
    }
}

//Plotly point-clicking functions
function get_point_locations(e) {
    last_mouse_location = [e.clientX, e.clientY];
    if(!!similarity_plot){
        if (e.path.indexOf(similarity_plot) > -1){
            //console.log(e.clientX);
            //console.log(e);
            point_centres = [];
            points = document.getElementsByClassName("points")[0].children;
            if (point_centres.length === 0){
                
                for (var p of points){
                    let bounding_rect = p.getBoundingClientRect();
                    let c_x = bounding_rect.left + bounding_rect.width/2;
                    let c_y = bounding_rect.top + bounding_rect.height/2;
                    point_centres.push({'centre' : [c_x, c_y], 'dist' : 0});
                }
            }
        }
    }
    d3.select(".cursor-crosshair").on("mousedown", find_nearest_point);
}


function find_nearest_point(e){
    var mouse = last_mouse_location;
    var current_min = 10000000;
    var min_index = -1;
    var current_index = 0;
    point_centres.map(function(p_c){
        var current_dist = mouse.dist(p_c.centre);
        p_c.dist = current_dist;
        if (current_dist < current_min){
            current_min = current_dist;
            min_index = current_index;
        }
        current_index++;
    });
    if (min_index === selected_rank){
        selected_rank = -1;
        return ;
    }else{
        selected_rank = min_index;
    }
    
    return rank_to_selection(min_index + 1);
}



Array.prototype.dist = function(b){
    var x = this[0] - b[0];
    var y = this[1] - b[1];
    return x*x + y*y;
};


function rank_to_selection(rank){
    var page = rank % 8 ? Math.floor(rank/8) + 1 : rank/8;
    var row = rank % 8 ? rank % 8 : 8;
    return goto_page(page, row);
}

function goto_page(i, row){
    deselect_rows();
    
    var table_num = $("table")[0].getAttribute("id").split(/_/)[2];
    var next = $("#DataTables_Table_" + table_num + "_next")[0];
    var previous = $("#DataTables_Table_" + table_num + "_previous")[0];
    var current_page = document.getElementsByClassName("current")[0].innerHTML;
    var page_shift = i - parseInt(current_page);
    var button = page_shift > 0 ? next : previous;
    for (var j = 0; j < Math.abs(page_shift); j++){
        button.click();
    }
    setTimeout(function() {return toggle_row(row)}, 1000);
}

function toggle_row(i){
    var rows = i % 2 ? document.getElementsByClassName("odd") : document.getElementsByClassName("even");
    var row = i % 2 ? Math.floor(i/2) : i/2 - 1;
    rows[row].click();
}


function deselect_rows(){
    var selected = document.getElementsByClassName("selected");
    for (var s = 0; s < selected.length; s++){
        selected[s].click();
    }
}


//Cluster selecting functions

function mp_finder(mp){
    var mp_tab = $("a")[2];
    mp_tab.click();
    var is_lords = mp.match(/^(Baron)|(Lord)|(The )|(Viscount)/);
    var radio_button = is_lords ? 0 : 1;
    $(".radio-inline")[radio_button].click()
    setTimeout(function(){
        $("#person_choice").append("<option value='" + mp + "'>" + mp + "</option>");
        $("#person_choice").val(mp).change();
        document.getElementsByClassName("item")[1].innerHTML = mp
        return; }, 500)
}

function topic_finder(topic){
    var topic_tab = $("a")[1];
    topic_tab.click();
    $("#topic_choice").append("<option value='" + topic + "'>" + topic + "</option>");
    $("#topic_choice").val(""+topic).change();
    document.getElementsByClassName("item")[0].innerHTML = topic;
}
