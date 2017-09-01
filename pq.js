var log = true;
var points;
var point_centres = [];
var last_mouse_location = [0,0];
var selected_rank = -1;
var search_rows = 10;
var text_to_return = "";



//Table-clicking function

function format(d, questionMPCol, tab) {
    console.log(d);
    d[3] = d[3].replace(/&lt;(.+?)&gt;/g, '<' + '$1' + '>');
    d[2] = d[2].replace(/&lt;(.+?)&gt;/g, '<' + '$1' + '>');
    if(tab == 'search') {
        buttonOne = '<button class=\"btn btn-info\" type = \"button\" onclick = \"mp_finder(\'' + d[questionMPCol] + '\')\">See all questions asked by<br>' + d[questionMPCol].replace(/([\w\s-]+), ([\w\s]+)/, '$2' + ' ' + '$1') + '</button>';
        buttonTwo = '<button class=\"btn btn-info\" type = \"button\" onclick = \"topic_finder(' + d[9] + ')\">View topic ' + d[9] + '<br>(' + d[10] + ') </button>';
    } else if (tab == 'topic') {
        buttonOne = '<button class=\"btn btn-info\" type = \"button\" onclick = \"mp_finder(\'' + d[questionMPCol] + '\')\">See all questions asked by ' + d[questionMPCol].replace(/([\w\s-]+), ([\w\s]+)/, '$2' + ' ' + '$1') + '</button>';
        buttonTwo = '<button class=\"btn btn-info\" type = \"button\" onclick = \"back_to_search()\">Back to search</button>';
    } else if (tab == 'member') {
        buttonOne = '<button class=\"btn btn-info\" type = \"button\" onclick = \"back_to_search()\">Back to search</button>';
        buttonTwo = '<button class=\"btn btn-info\" type = \"button\" onclick = \"topic_finder(' + d[9] + ')\">View topic ' + d[9] + ' (' + d[10] + ') </button>';
    }

    return '<div style=\"background-color:#eee; padding: 1em; margin: 1em; word-wrap:break-word;\"><h4>Question</h4><p>' +
                d[2] +
                '</p><h4>Answer</h4><p>' + d[3] + '</p></div>' +
                '<div class=\"container-fluid\">' +
                '<div class=\"btn-group btn-group-justified\" role=\"group\">' +
                '<div class=\"btn-group\" role=\"group\">' +
                buttonOne +
                '</div>' +
                '<div class=\"btn-group\" role=\"group\">' +
                buttonTwo +
                '</div>' +
                '</div>' +
                '</div>';
}
var questionMPCol;
var tab;
var search_table;
var topic_table;
var member_table;

function rowActivate() {
    //Set global variables depending on tab user is on.  
    //The id of the active tab (div.active) ends in either a 1, 2, or 3 depending on the tab.
    //This is the first thing to double check if this starts breaking.
    var active_tab = $("div.active")[0].getAttribute("id").slice(-1)
    tab = active_tab === "1" ? "search" : active_tab === "2" ? "topic" : "member" 
    console.log(tab)
    var table1 = tab === "search" ? search_table : tab === "topic" ? topic_table : member_table;
    questionMPCol = tab === "search" ? 6 : 4;
    
    
    var row = this.closest('tr');
    var showHideIcon = $(row.firstChild);
    var shinyRow = table1.row(row);
    if (shinyRow.child.isShown()) {
        shinyRow.child.hide();
        showHideIcon.html('&oplus;');
    } else {
        shinyRow.child(format(shinyRow.data(), questionMPCol, tab)).show();
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
            //Get the correct points group:
            for (var group of $("g.points")){
                points = group.children;
                if(points.length > search_rows){
                    break;
                }
            }
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
    
    var cc = document.getElementsByClassName("cursor-crosshair")[0];
    if(cc){
        cc.addEventListener("mousedown", find_nearest_point);
    }
    $("div.active").keydown(table_check)
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
    
    return rank_to_selection(min_index + 1, search_rows);
}



Array.prototype.dist = function(b){
    var x = this[0] - b[0];
    var y = this[1] - b[1];
    return x*x + y*y;
};


function rank_to_selection(rank, search_rows){
    var page = rank % search_rows ? Math.floor(rank/search_rows) + 1 : rank/search_rows;
    var row = rank % search_rows ? rank % search_rows : search_rows;
    return goto_page(page, row);
}

function goto_page(i, row){
    deselect_rows();
    
    var table_num = $("table")[0].getAttribute("id").split(/_/)[2];
    var next = $("#DataTables_Table_" + table_num + "_next")[0];
    var previous = $("#DataTables_Table_" + table_num + "_previous")[0];
    var current_page = document.getElementsByClassName("current")[0].innerHTML;
    var page_shift = i - parseInt(current_page);
    var buttons = $("a.paginate_button");
    var target;
    var first_click_timeout = 200;
    if (page_shift === 0){
        return row_timeout(row);
    }
    //Page jumping logic
    if(current_page <= 4){
        //one click
        target = [0,1,2,3,4,5,10].indexOf(i);
        if( target > -1){
            buttons[target].click();
            return row_timeout(row);
        }else{//two clicks
            buttons[6].click(); //get to page 10
            setTimeout(function(){
                buttons = $("a.paginate_button");
                target = [0,1,6,7,8,9].indexOf(i);
                buttons[target].click();
                return row_timeout(row);
            }, first_click_timeout);
        }
    }else if(current_page >= 7){
        //one click
        target = [0,1,6,7,8,9,10].indexOf(i);
        if( target > -1){
            buttons[target].click();
            return row_timeout(row);
        }else{//two clicks
            buttons[1].click(); //get to page 1
            setTimeout(function(){
                buttons = $("a.paginate_button");
                target = [0,1,2,3,4,5].indexOf(i);
                buttons[target].click();
                return row_timeout(row);
            }, first_click_timeout)
        }
    }else{//current_page in [5,6,7]
        if (Math.abs(page_shift) === 1){
            var button = page_shift > 0 ? next : previous;
            button.click();
        }else if(i < 5){
            buttons[1].click(); //get to page 1
            setTimeout(function(){
                buttons = $("a.paginate_button");
                target = [0,1,2,3,4,5].indexOf(i);
                buttons[target].click();
                return row_timeout(row);
            }, first_click_timeout)
            
        }else{
            buttons[6].click(); //get to page 10
            setTimeout(function(){
                buttons = $("a.paginate_button");
                target = [0,6,7,8,9].indexOf(i);
                buttons[target].click();
                return row_timeout(row);
            }, first_click_timeout);
        }
    }
}

function row_timeout(row){
    setTimeout(function() {return toggle_row(row)}, 200);
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

//function walkthrough_button_clicking(){
//  debugger
//  if (this._currentStep==6) {
//    $(".btn-info")[0].trigger("mouseup", function(){
//      debugger
//      setTimeout(function(){
//          $(".introjs-nextbutton").click()
//        }, 100)
//      })
//  }
//}

//Cluster selecting functions

//Note the fixed indices in various things below (lines) - should be fine for now, but this is likely where any future errors may come from, supposing they do.

function mp_finder(mp){
    var mp_tab = $("a")[2]; //find link to MP tab
    mp_tab.click(); //click on link (takes us to MP tab)
    var is_lords = mp.match(/^(Baron)|(Lord)|(The )|(Viscount)/); //determine if mp is in HoL or HoC
    var radio_button = is_lords ? 0 : 1; //is_lords evalutes to true if above match is found, and false otherwise - returnin 0, 1 respectively
    $(".radio-inline")[radio_button].click(); //Click the correct radio button, as determined by is_lords
    
    setTimeout(function(){ //timeout to give radio button click enough time to execute
        $("#person_choice").append("<option value='" + mp + "'>" + mp + "</option>"); //append option to person dropdown (the mp you want)
        $("#person_choice").val(mp).change(); //change to new option
        document.getElementsByClassName("item")[1].innerHTML = mp; //change text in person dropdown
        return; }, 500);
}

function topic_finder(topic){
    var topic_tab = $("a")[1]; //find link to topic tab
    topic_tab.click(); //click on link (takes us to topic tab)
    $("#topic_choice").append("<option value='" + topic + "'>" + topic + "</option>"); //append option to topic dropdown (the topic you want)
    $("#topic_choice").val(""+topic).change(); //change to new option
    document.getElementsByClassName("item")[0].innerHTML = topic; //change text in topic dropdown
}

function back_to_search(){
    var search_tab = $("a")[0];
    search_tab.click();
}


//Tidy up tab tables

String.prototype.format_html = function(){
    return this.replace(/&lt;(.+?)&gt;/g, '<' + '$1' + '>');
};

function table_check(){
    var tableCheck = window.setInterval(empty_table, 20)
    setTimeout(function(){
        clearInterval(tableCheck)
    }, 1000)
}

function empty_table(){
    if(question.value.length === 0){
        return;
    }
    if(!!similarity_table){
        var page_links = $("#similarity_table").find("a")
        if (page_links.length < 3){
            page_links.remove()
            $("#similarity_table").find(".dataTables_info")[0].innerHTML = ""
            $("#similarity_table").find("th")[0].innerHTML = ""
            $("#similarity_table").find("td")[0].style['white-space'] = 'pre'
            $("#similarity_table").find("td")[0].innerHTML = "Sorry, no matches for that!\nTry searching additional words, or checking for typos."
        }
    }
}


function tidy_table(){
    //deprecated
    //Find Answer_text column
    var headers = $("div.active").find("th.sorting");
    var hl = headers.length;
    var answer_index = -1;
    var table_entries = $("div.active").find("td");
    var t_entries_length = table_entries.length;
    for(var h of headers){
        answer_index++;
        if(h.innerHTML === "Answer_Text"){
            break;
        }
    }
    for(var i = 0; i < t_entries_length; i++){
        if(i % hl !== answer_index){
            continue;
        }
        var a_text = table_entries[i].innerHTML;
        table_entries[i].innerHTML = a_text.format_html();
    }
}
 
 //function codeAddress() {
//    alert("Welcome! Just a quick reminder that I cannot be run in Internet Explorer, try Mozille Firefox or Google Chrome instead.")
//  }

//  window.onload = codeAddress;

//Walkthrough fixing


