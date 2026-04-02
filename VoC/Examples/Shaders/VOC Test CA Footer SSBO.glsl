layout(std430, binding=3) buffer myBuffer
{
  //2D array
  //double data[image_width][image_height];
  //1D array
  double data[image_width*image_height];
};

void main()
{
    double array_value=0.0;
	
	int pixel_x = int(gl_FragCoord.x);
	int pixel_y = int(gl_FragCoord.y);

    //if ((pixel_x<200)&&(pixel_y<100)) {
        //2D array
		//array_value = data[pixel_x][pixel_y];
		//1D array
		array_value = data[pixel_x+int(resolution.y)*pixel_y];
    //} else {
    //    array_value = 1.0;
    //}
    
    gl_FragColor=vec4(array_value,array_value,array_value,1.0);
}
