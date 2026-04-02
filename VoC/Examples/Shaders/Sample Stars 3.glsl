#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159
const float indent = 0.06;
float angular=5.;

float hash( float n )
{
    return fract( (1.0 + cos(n)) * 415.92653);
}

float noise2d( in vec2 x )
{
    float xhash = hash( x.x * 37.0 );
    float yhash = hash( x.y * 57.0 );
    return fract( xhash + yhash );
}

float drawStar(vec2 o,float size,float startAngle){
    vec2 q=o;
    q*=normalize(resolution).xy;
//    float startAngle = -time / size*0.001;
   //float startAngle=size*1000.;
   
    mat4 RotationMatrix = mat4( cos( startAngle ), -sin( startAngle ), 0.0, 0.0,
                sin( startAngle ),  cos( startAngle ), 0.0, 0.0,
                         0.0,           0.0, 1.0, 0.0,
                     0.0,           0.0, 0.0, 1.0 );    
    q = (RotationMatrix * vec4(q, 0.0, 1.0)).xy;
    
    float angle=atan( q.y,q.x )/(2.*pi);
    

    float segment = angle * angular;
    
    
    float segmentI = floor(segment);
    float segmentF = fract(segment);
        
    angle = (segmentI + 0.5) / angular;
    
    if (segmentF > 0.5) {

        angle -= indent;
    } else
    {

        angle += indent;
    }
    angle *= 2.0 * pi;

    vec2 outline;
    outline.y = sin(angle);
    outline.x = cos(angle);
    
    float dist = abs(dot(outline, q));
    
    float ss=size*(1.+0.2*sin(time*hash(size)*20. ) );
    float r=angular*ss;
    
    
    
    float star=smoothstep( r, r+0.005, dist );
    
    
    return star;
}

float drawFlare(vec2 o,float size){
    o*=normalize(resolution).xy;
    float flare=smoothstep(0.0,size,length(o) );
    return flare;
}

vec4 mI(in vec2 fragCoord)
{
    
    vec2    iResolution=resolution;
    float iGlobalTime=time;
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    // first texture row is frequency data
    //float fft  = texture2D( iChannel0, vec2(uv.x,0.25) ).x; 
    
    // second texture row is the sound wave
    //float wave = texture2D( iChannel0, vec2(uv.x,0.75) ).x;

    vec3 color=mix(vec3(0.), vec3(0.1,0.2,0.4), uv.y );
    float fThreshhold = 0.995;
    float StarVal = noise2d( uv );
    if ( StarVal >= fThreshhold )
    {
        StarVal = pow( (StarVal - fThreshhold)/(1.0 - fThreshhold), 6.0 );

        color += vec3( StarVal );
    }

    for (float i=0.;i<100.;i++){
   
        float t0=i*0.1;
        
        if (iGlobalTime>t0){
            float t=mod(iGlobalTime-t0,5.5) ;
            float size=1.+3.0*hash(i*10.);// sin(1.*t+(hash(i*10.)-0.5)*pi ) ;
            //size=mix(4.0,0.0,t/5.5);
  //          size=0.;
            
            vec2 pos=uv-vec2( 0.5+0.25*(hash(i)-0.5)*t ,
                          0.0+(0.5 +0.5*hash(i+1.) )*t- .2*t*t ) ;
            
            color+=mix(vec3(0.05,0.05,0.),vec3(.0),drawFlare(pos,0.05*size) );
            
            color=mix( vec3(0.9+hash(i),0.9,0.0),color ,
                  drawStar(pos,0.0005*size, pi*hash(i+1.) ) );    
            
        }
    }

    return vec4( color,1.0);

}

void main( void ) {
    /*
    vec2 position = ( gl_FragCoord.xy / resolution.xy ) + mouse / 4.0;
    
    float color = 0.0;
    color += sin( position.x * cos( time / 15.0 ) * 80.0 ) + cos( position.y * cos( time / 15.0 ) * 10.0 );
    color += sin( position.y * sin( time / 10.0 ) * 40.0 ) + cos( position.x * sin( time / 25.0 ) * 40.0 );
    color += sin( position.x * sin( time / 5.0 ) * 10.0 ) + sin( position.y * sin( time / 35.0 ) * 80.0 );
    color *= sin( time / 10.0 ) * 0.5;
    */
    vec4 color=mI(gl_FragCoord.xy);
    
    glFragColor=color;
//    glFragColor = vec4( vec3( color, color * 0.5, sin( color + time / 3.0 ) * 0.75 ), 1.0 );

}
