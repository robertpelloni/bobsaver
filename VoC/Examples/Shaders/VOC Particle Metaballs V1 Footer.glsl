    color *= threshold;
    color = clamp(color, 0., 1.);
    return color;
}

void main(void)
{
    //vec2 uv = gl_FragCoord.xy / resolution.xy;
    //uv is pixel coordinates between -1 and +1 in the X and Y axiis with aspect ratio correction
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 color = doballs(uv);

	/*
	#define ANTIALIAS 2

    #ifdef ANTIALIAS
    float uvs = .75 / resolution.y;
    color *= .5;
    color += doballs(vec2(uv.x + uvs, uv.y))*.125;
	color += doballs(vec2(uv.x - uvs, uv.y))*.125;
    color += doballs(vec2(uv.x, uv.y + uvs))*.125;
    color += doballs(vec2(uv.x, uv.y - uvs))*.125;
    
    #if ANTIALIAS == 2
  	color *= .5;
    color += doballs(vec2(uv.x + uvs*.85, uv.y + uvs*.85))*.125;
    color += doballs(vec2(uv.x - uvs*.85, uv.y + uvs*.85))*.125;
    color += doballs(vec2(uv.x - uvs*.85, uv.y - uvs*.85))*.125;
    color += doballs(vec2(uv.x + uvs*.85, uv.y - uvs*.85))*.125;
    #endif
    #endif
	*/
	
    glFragColor = vec4(color, 1.);
}
