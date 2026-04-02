#version 420

// original https://www.shadertoy.com/view/wtGSz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define GRID_SCALE vec2(10.,1.)
#define PARTICLE_SWAY_SCALE 1.
#define PARTICLE_SIZE_SCALE .6
#define PARTICLE_SPEED_SCALE 1.4

float r21(vec2 p) {
    return fract(sin(dot(p.xy ,vec2(12.9898,78.233))) * 4558.5453);
}

vec2 r22(vec2 p) {
    float f = r21(p);
    return vec2( f, floor(f)+fract(fract(f)*100.) );
}

float column(vec2 p) {
    return floor(p.x);
}

vec2 cell_to_screen(vec2 cell_pos, float column_id) {
    return vec2(column_id + cell_pos.x/10., cell_pos.y);
}

vec3 column_paint(float column_id, vec2 cell_pos, float offs, float depth) {
    vec3 col=vec3(0.0);
    
    for (float i=1.;i<=20.;i++) {
        float transparency_scale = (10.-depth)/10.;
        
        float scale = (20.3-i)/20. * PARTICLE_SIZE_SCALE;
        
        float time = mix(time,time*(1.-transparency_scale),.5) * PARTICLE_SPEED_SCALE  -.005*i + depth*1125.634;
        
        float offsY = time + column_id;
        float randY = 5. + r21(vec2(column_id)+.6); 

        vec2 fake_dot_pos = vec2(.5 + PARTICLE_SWAY_SCALE * cos(time+column_id*23.+depth*12546.325346345673457),mod(offsY + randY,1.));

        col += smoothstep(.007*scale,0.,distance(cell_to_screen(cell_pos, column_id),vec2(offs*.1,0)+cell_to_screen(fake_dot_pos,column_id)));
        col += vec3(1.,.7,0.) * .5 * smoothstep(.015*scale,0.,distance(cell_to_screen(cell_pos, column_id),vec2(offs*.1,0)+cell_to_screen(fake_dot_pos,column_id)));
    
    }
    
    return col;
}

vec3 layer(float depth, vec2 uv) {
    vec3 col=vec3(0.0);
    vec2 p = uv.xy * GRID_SCALE;
    vec2 cell_pos = mod(p,1.);
   
    float column_id = column(p);
    
    col += column_paint(column_id-1.+depth*22., cell_pos,-1.,depth);
    col += column_paint(column_id+depth*22., cell_pos, 0.,depth);
    col += column_paint(column_id+1.+depth*22., cell_pos,1., depth);
    
    return col*depth/10.;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 col=vec3(0.0);
    
    col += vec3(0.,.35,1.)*.125;
    col += vec3(1.,.4,.1) * (1.-uv.y) * (.3 + .02*cos(time*15.));
    col += vec3(1.,.4,.1) * .01*cos(time*23.+2.3);
    
    for (float x = 1.; x<10.; x++) {
        col += layer(x, uv);
    }
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
