class UploadImageModalView extends KDModalView

  constructor : (options = {}, data) ->
    options.title         ?= "Upload photo"
    options.uploaderTitle ?= "Drag & drop image here!"
    options.overlay       ?= yes
    options.preview       ?= options.image
    options.overlayClick  ?= no
    options.buttons       ?=
      uploadButton         :
        title              : "Upload"
        cssClass           : "modal-clean-green"
        callback           : @bound "upload"

    super options, data

    @uploaderView    = new DNDUploader
      title          : @getOptions().uploaderTitle
      uploadToVM     : no
      size           : @getOptions().preview.size

    @loaderView  = new KDLoaderView
      showLoader     : no
      cssClass       : "hidden"
      size           :
        width        : 32

    @uploaderView.on "dropFile", ({origin, content})=>
      if origin is "external"
        @previewData = "data:image/png;base64,#{btoa content}"
        @uploaderView.updatePartial ""
        @updateLogoImage()

    @addSubView @uploaderView
    @addSubView @loaderView

  updateLogoImage : =>
    @logoPreview?.destroy()
    @logoPreview = new KDCustomHTMLView
      tagName    : "figure"
      size       : @getOptions().preview.size

    @logoPreview.setStyle
      "background-image" : "url(#{@previewData})"

    @uploaderView.addSubView @logoPreview

  uploadToS3: (avatarData, callback)->
    #TODO : change the address and name of the logo
    {groupsController} = KD.singletons
    groupsController.ready =>

      group     = groupsController.getCurrentGroup()
      imageType = @getOptions().image.type
      imageName = "#{group.slug}-#{imageType}-#{Date.now()}.png"

      FSHelper.s3.upload imageName, avatarData, (err, url)=>
        if err
          new KDNotificationView title : "Error while uploading photo."
          @loaderView.hide()
          return

        group = KD.singletons.groupsController.getCurrentGroup()

        if @getOptions().image.type is "coverPhoto"
          group.modify "customize.coverPhoto" : "#{url}", callback
        else
          group.modify "customize.logo" : "#{url}", callback

  upload:(callback)->

    return new KDNotificationView title : 'Please drag & drop an image to upload!'  unless @previewData

    @loaderView.show()
    [_, logoBase64] = @previewData.split ","
    @uploadToS3 logoBase64, (err)=>
      @loaderView.hide()
      callback? err
