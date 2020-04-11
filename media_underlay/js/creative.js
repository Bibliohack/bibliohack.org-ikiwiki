(function($) {
  "use strict"; // Start of use strict

  // Smooth scrolling using jQuery easing
  $('a.js-scroll-trigger[href*="#"]:not([href="#"])').click(function() {
    if (location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') && location.hostname == this.hostname) {
      var target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
      if (target.length) {
        $('html, body').animate({
          scrollTop: (target.offset().top - 57)
        }, 1000, "easeInOutExpo");
        return false;
      }
    }
  });

  // Closes responsive menu when a scroll trigger link is clicked
  $('.js-scroll-trigger').click(function() {
    $('.navbar-collapse').collapse('hide');
  });

  // Activate scrollspy to add active class to navbar items on scroll
  $('body').scrollspy({
    target: '#mainNav',
    offset: 57
  });

  // Collapse Navbar
  var navbarCollapse = function() {
    if ($("#mainNav").length != 0) {
	    if ($("#mainNav").offset().top > 100) {
	      $("#mainNav").addClass("navbar-shrink");
	    } else {
	      $("#mainNav").removeClass("navbar-shrink");
	    }
	  }
  };
  // Collapse now if page is not at top
  navbarCollapse();
  // Collapse the navbar when page is scrolled
  $(window).scroll(navbarCollapse);

  // Scroll reveal calls
  window.sr = ScrollReveal();
  sr.reveal('.sr-icons', {
    duration: 600,
    scale: 0.3,
    distance: '0px'
  }, 200);
  sr.reveal('.sr-button', {
    duration: 1000,
    delay: 200
  });
  sr.reveal('.sr-contact', {
    duration: 600,
    scale: 0.3,
    distance: '0px'
  }, 300);

  // Magnific popup calls
  $('.popup-gallery').magnificPopup({
    delegate: 'a',
    type: 'image',
    tLoading: 'Loading image #%curr%...',
    mainClass: 'mfp-img-mobile',
    gallery: {
      enabled: true,
      navigateByImgClick: true,
      preload: [0, 1]
    },
    image: {
      tError: '<a href="%url%">The image #%curr%</a> could not be loaded.'
    }
  });

	$(window).bind('keydown', function(event) {
	    if (event.ctrlKey || event.metaKey) {
	        switch (String.fromCharCode(event.which).toLowerCase()) {
	        case 'e':
	            event.preventDefault();
	            // alert('ctrl-e');
					$('.edit-element').toggleClass("visible");
	            break;
	        }
	    }
	});
})(jQuery); // End of use strict

/**
 * Author and copyright: Stefan Haack (https://shaack.com)
 * Repository: https://github.com/shaack/jquery-background-slideshow/
 * License: MIT, see file 'LICENSE'
 */

;(function ($) {
    "use strict"
    $.fn.backgroundSlideshow = function (options) {

        this.each(function () {

            var $container = $(this)
            var $caption_container = $("#slider-epigrafes span")
            var $currentLayer = null
            var $nextLayer = null
            var currentImageIndex = 0
            var nextImageIndex = 0
            var preloadedImages = []
            var config = {
                delay: 6000,
                transitionDuration: 3000,
                onBeforeTransition: null,
                onAfterTransition: null,
                fixed: false,
                images: []
            }
            for (var option in options) {
                config[option] = options[option]
            }
            var layerStyles = {
                backgroundSize: "cover",
                backgroundRepeat: "no-repeat",
                backgroundPosition: "center center",
                position: config.fixed ? "fixed" : "absolute",
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                zIndex: -1
            }

            function preLoadImage(index) {
                if (!preloadedImages[index]) {
                    preloadedImages[index] = new Image()
                    preloadedImages[index].src = config.images[index]
                }
            }

            function addLayer(imageSrc) {
                var $newLayer = $("<div class='backgroundSlideshowLayer'/>")
                var thisLayerStyles = layerStyles
                thisLayerStyles.backgroundImage = "url(" + imageSrc + ")"
                $newLayer.css(thisLayerStyles)
                var $lastLayer = $container.find("> .backgroundSlideshowLayer").last()
                if ($lastLayer[0]) {
                    $lastLayer.after($newLayer)
                } else {
                    $container.prepend($newLayer)
                }
                $newLayer.hide()
                return $newLayer
            }

            function showCaption(index) {
            	$caption_container.html( 
            		config.captions[index][0] )
           		.animate({
             	    opacity: 1,
             	    // bottom: "+=25"
           		}, 200)
            }
            function hideCaption(index) {
            	if(index > 0){
	            	$caption_container.delay(1000).animate(
	            		{opacity: 0}, 200
	            	)
            	}
            }
            function nextImage(transition) {
                currentImageIndex = nextImageIndex
                nextImageIndex++
                if (nextImageIndex >= config.images.length) {
                    nextImageIndex = 0
                }
                if ($nextLayer) {
                    $currentLayer = $nextLayer
                } else {
                    $currentLayer = addLayer(config.images[currentImageIndex])
                }
                if (config.onBeforeTransition) {
                    config.onBeforeTransition(currentImageIndex)
                }
                hideCaption(currentImageIndex)
                if (transition) {
                    $currentLayer.fadeIn(config.transitionDuration, function () {
                        if (config.onAfterTransition) {
                            config.onAfterTransition(currentImageIndex)
                        }
                        preLoadImage(nextImageIndex)
                        showCaption(currentImageIndex)
                        $nextLayer = addLayer(config.images[nextImageIndex])
                        cleanUp()
                    })
                } else {
                    $currentLayer.show()
                    if (config.onAfterTransition) {
                        config.onAfterTransition(currentImageIndex)
                        setTimeout(function () {
                            preLoadImage(nextImageIndex)
                            $nextLayer = addLayer(config.images[nextImageIndex])
                            cleanUp()
                        }, config.delay / 2)
                    }
                }
            }

            function cleanUp() {
                var $layers = $container.find("> .backgroundSlideshowLayer")
                if ($layers.length > 2) {
                    $layers.first().remove()
                }
            }


            nextImage(false)
	      	var cycle = false
            $container.css("position", "relative")


				// stop / start cycle by mainNav offset position
			   var checkOffset = function() {
			   	if ($("#mainNav").length != 0) {
				   	if ($("#mainNav").offset().top > 500) {
				      	if(cycle !== false) { 
				      		clearInterval(cycle) 
					      	cycle = false
					      	console.log("Cycle clear")
				      	}
				    	} else {
				   	   if (cycle === false) {
					      	console.log("Cycle start")
		                  cycle = setInterval(function () {
			                  nextImage(true)
			               }, config.delay + config.transitionDuration)
				      	}
				    	}
			    	}
				}
				
				checkOffset()
				$(window).scroll(checkOffset)
        })
    }
}(jQuery))
