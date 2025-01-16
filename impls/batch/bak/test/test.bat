			for /f "delims==" %%i in (
				'set ^& set'
			) do (
				echo set "%%i="
			)
			pause