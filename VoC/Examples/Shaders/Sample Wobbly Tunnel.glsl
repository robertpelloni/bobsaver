#version 420

// original https://www.shadertoy.com/view/tdK3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define num_circles 70
#define inner_circles 4

void main(void)
{
     vec2 center = vec2( 0.5, 0.5 );
//    vec2 pixel_pos = gl_FragCoord.xy/resolution.x;
    vec2 pixel_pos = gl_FragCoord.xy/resolution.x;
    pixel_pos = pixel_pos - vec2( 0.5, 0.5-0.5*resolution.y/resolution.x );
    
    float target_alpha = 0.0;
    vec3 final_color = vec3(0,0,0);

    float mod_time = mod(time,0.2*5.0);
    vec3 color_target;
    for( int idx = 0; idx<num_circles; idx++ ) 
    {
        float float_idx = float(idx);
        float color_step = 0.7 / float(num_circles);
        color_target = vec3( 0.8 - float(idx)*color_step, 0.5-float(idx)*color_step, 0.6);
        float dist = 0.0;

        float scale = float( idx+10 )/30.0;
        vec2 adjusted_pos = pixel_pos * scale;
        // Calculate a 'center' for each layer
        vec2 base_position = vec2( sin( time*0.4923+float_idx*0.132135 )*0.09187*float_idx/20.0,
                                sin( time*0.577125+float_idx*0.20197)*0.079*float_idx/20.0 );

        // the layer outline is created by using a meta-circle. by creating
        // moving point charges which create  
        for( int idx2 = 0; idx2 < inner_circles; idx2 ++ ) 
        {
            vec2 circle  = base_position + vec2( sin( time*0.192+float(idx2)*0.31135 )*0.2415,
                                                sin( time*.4213+float(idx2)*1.1211 )*0.243 );
            dist = dist + 1.0 / dot( circle-adjusted_pos, circle-adjusted_pos );
        }
        dist = dist *  0.0312116;

        float threshold = 0.796;// / scale;
        float alpha = smoothstep( threshold, threshold-0.01*scale, dist );

        final_color = mix( final_color, alpha*color_target, max( 0.0, alpha-target_alpha ) );
        target_alpha = alpha + target_alpha;
    }
    final_color = mix( final_color, color_target, max( 0.0, 1.0-target_alpha )  );

    glFragColor = vec4( final_color, 1.0 );
}
