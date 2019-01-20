$(document).ready(function(){
    var domainIsOk = false,
	fileSizeIsOk = false;
    $('#file').bind('change', function() {
	var fs = 0;
        for(var i=0;i<this.files.length;i++)
        {
	    fs += parseInt((this.files[i].size/1024/1024).toFixed(2));
        }
        var maxuploadmb = 50;
        if(maxuploadmb<fs){
    	    fileSizeIsOk = false;
	    alert("Размер файла ("+fs+" Мб) превышает лимит в "+maxuploadmb+" Мб");
	    $("#file").val("");
    	}else {
    	    fileSizeIsOk = true;
    	}
    });
        
	$('#sub_dom_name').change(function(){
		$.ajax({ 
			type: "POST",
 			url: "/check.php",
  			data: { "subdomain": $( this ).val() },
  			success: function( data ) {
				var tag = '<span class="'+data['result']+'">'+data['mes']+'</span>';
				if(data['result'] == 'success' ) {
				    domainIsOk = true;
				}else{
				    domainIsOk = false;
				}
				$('#result_block').html(tag);
			}, 
  			dataType: "json"
		});
	});
	
	$("#upload").validate({
	    submitHandler: function(frm) {
		openProgressBar();
		$(frm).ajaxSubmit({
		    target: "#result_block",
		    beforeSubmit: function(arr, $form, options) {
			if(!domainIsOk || !fileSizeIsOk) return false;
	    		$("#send_button").attr("disabled","disabled");
	    		$("#send_button").val("Uploading...");
			$("#result_block").html("Wait please...");
		    },
		    success: function() {
			$(frm)[0].reset();
	    		$("#send_button").removeAttr("disabled");
			$("#send_button").val("Send");
		    }
		})
	    },
	    focusInvalid: false,
	    focusCleanup: true,
	    rules: {
		sub_dom_name: {required: true},
		file: {required: true}
	    }
	});
});
