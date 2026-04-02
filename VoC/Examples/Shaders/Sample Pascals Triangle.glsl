#version 420

uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform float time;

out vec4 glFragColor;

void main( void ) {
    //Recursively shading Pascal's triangle mod n.
    float n=2.0;//Change n to see what happens. Don't be afraid to try non-integer values as well!
    //Try moving your mouse to disturb the pattern.
    float m=n-1.0;
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 pix=(1.0/resolution.xy);
    if(gl_FragCoord.x<=0.5||gl_FragCoord.y<=0.5){
        glFragColor=vec4(0.0,0.0,0.0,1.0);
    }
    else if(gl_FragCoord.x<=1.5&&gl_FragCoord.y<=1.5){
        glFragColor = vec4( 1.0,1.0,1.0, 1.0 );
    }
    else if(length((position-mouse)*vec2(resolution.x/resolution.y,1.0))<0.01){
        glFragColor = vec4( 0.0,0.0,0.0, 1.0 );
    }
    else{
        float left=texture2D(backbuffer,position-vec2(pix.x,0.0)).x*m;
        float bottom=texture2D(backbuffer,position-vec2(0.0,pix.y)).x*m;
        float value=mod(left+bottom,n)/m;
        glFragColor = vec4(value,value,value, 1.0 );
    }
}
//Made by willy-vvu. Check out my github page at http://github.com/willy-vvu or my homepage at http://willy.herokuapp.com
