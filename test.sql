ALTER TABLE [dbo].[constructorResults]  WITH CHECK ADD  CONSTRAINT [FK_constructorResults_constructorId] FOREIGN KEY([constructorId])
REFERENCES [dbo].[constructors] ([constructorId])
GO

ALTER TABLE [dbo].[constructorResults] CHECK CONSTRAINT [FK_constructorResults_constructorId]
GO

ALTER TABLE [dbo].[constructorResults]  WITH CHECK ADD  CONSTRAINT [FK_constructorResults_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[constructorResults] CHECK CONSTRAINT [FK_constructorResults_raceId]
GO

ALTER TABLE [dbo].[constructorStandings]  WITH CHECK ADD  CONSTRAINT [FK_constructor_standings_constructorId] FOREIGN KEY([constructorId])
REFERENCES [dbo].[constructors] ([constructorId])
GO

ALTER TABLE [dbo].[constructorStandings] CHECK CONSTRAINT [FK_constructor_standings_constructorId]
GO

ALTER TABLE [dbo].[constructorStandings]  WITH CHECK ADD  CONSTRAINT [FK_constructor_standings_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[constructorStandings] CHECK CONSTRAINT [FK_constructor_standings_raceId]
GO

ALTER TABLE [dbo].[driverStandings]  WITH CHECK ADD  CONSTRAINT [FK_driver_standings_standings_driverid] FOREIGN KEY([driverId])
REFERENCES [dbo].[drivers] ([driverId])
GO

ALTER TABLE [dbo].[driverStandings] CHECK CONSTRAINT [FK_driver_standings_standings_driverid]
GO

ALTER TABLE [dbo].[driverStandings]  WITH CHECK ADD  CONSTRAINT [FK_driver_standings_standings_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[driverStandings] CHECK CONSTRAINT [FK_driver_standings_standings_raceId]
GO

ALTER TABLE [dbo].[lapTimes]  WITH CHECK ADD  CONSTRAINT [FK_lap_times_drivers] FOREIGN KEY([driverId])
REFERENCES [dbo].[drivers] ([driverId])
GO

ALTER TABLE [dbo].[lapTimes] CHECK CONSTRAINT [FK_lap_times_drivers]
GO

ALTER TABLE [dbo].[lapTimes]  WITH CHECK ADD  CONSTRAINT [FK_lap_times_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[lapTimes] CHECK CONSTRAINT [FK_lap_times_raceId]
GO

ALTER TABLE [dbo].[pitStops]  WITH CHECK ADD  CONSTRAINT [FK_pit_stops_driverid] FOREIGN KEY([driverId])
REFERENCES [dbo].[drivers] ([driverId])
GO

ALTER TABLE [dbo].[pitStops] CHECK CONSTRAINT [FK_pit_stops_driverid]
GO

ALTER TABLE [dbo].[pitStops]  WITH CHECK ADD  CONSTRAINT [FK_pit_stops_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[pitStops] CHECK CONSTRAINT [FK_pit_stops_raceId]
GO

ALTER TABLE [dbo].[qualifying]  WITH CHECK ADD  CONSTRAINT [FK_qualifying_constructorId] FOREIGN KEY([constructorId])
REFERENCES [dbo].[constructors] ([constructorId])
GO

ALTER TABLE [dbo].[qualifying] CHECK CONSTRAINT [FK_qualifying_constructorId]
GO

ALTER TABLE [dbo].[qualifying]  WITH CHECK ADD  CONSTRAINT [FK_qualifying_driverid] FOREIGN KEY([driverId])
REFERENCES [dbo].[drivers] ([driverId])
GO

ALTER TABLE [dbo].[qualifying] CHECK CONSTRAINT [FK_qualifying_driverid]
GO

ALTER TABLE [dbo].[qualifying]  WITH CHECK ADD  CONSTRAINT [FK_qualifying_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[qualifying] CHECK CONSTRAINT [FK_qualifying_raceId]
GO

ALTER TABLE [dbo].[races]  WITH CHECK ADD  CONSTRAINT [FK_races_circuitId] FOREIGN KEY([circuitId])
REFERENCES [dbo].[circuits] ([circuitId])
GO

ALTER TABLE [dbo].[races] CHECK CONSTRAINT [FK_races_circuitId]
GO

ALTER TABLE [dbo].[races]  WITH CHECK ADD  CONSTRAINT [FK_races_year] FOREIGN KEY([year])
REFERENCES [dbo].[seasons] ([year])
GO

ALTER TABLE [dbo].[races] CHECK CONSTRAINT [FK_races_year]
GO

ALTER TABLE [dbo].[results]  WITH CHECK ADD  CONSTRAINT [FK_results_constructorId] FOREIGN KEY([constructorId])
REFERENCES [dbo].[constructors] ([constructorId])
GO

ALTER TABLE [dbo].[results] CHECK CONSTRAINT [FK_results_constructorId]
GO

ALTER TABLE [dbo].[results]  WITH CHECK ADD  CONSTRAINT [FK_results_driverid] FOREIGN KEY([driverId])
REFERENCES [dbo].[drivers] ([driverId])
GO

ALTER TABLE [dbo].[results] CHECK CONSTRAINT [FK_results_driverid]
GO

ALTER TABLE [dbo].[results]  WITH CHECK ADD  CONSTRAINT [FK_results_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[results] CHECK CONSTRAINT [FK_results_raceId]
GO

ALTER TABLE [dbo].[sprintResults]  WITH CHECK ADD  CONSTRAINT [FK_sprint_results_constructorId] FOREIGN KEY([constructorId])
REFERENCES [dbo].[constructors] ([constructorId])
GO

ALTER TABLE [dbo].[sprintResults] CHECK CONSTRAINT [FK_sprint_results_constructorId]
GO

ALTER TABLE [dbo].[sprintResults]  WITH CHECK ADD  CONSTRAINT [FK_sprint_results_driverid] FOREIGN KEY([driverId])
REFERENCES [dbo].[drivers] ([driverId])
GO

ALTER TABLE [dbo].[sprintResults] CHECK CONSTRAINT [FK_sprint_results_driverid]
GO

ALTER TABLE [dbo].[sprintResults]  WITH CHECK ADD  CONSTRAINT [FK_sprint_results_raceId] FOREIGN KEY([raceId])
REFERENCES [dbo].[races] ([raceId])
GO

ALTER TABLE [dbo].[sprintResults] CHECK CONSTRAINT [FK_sprint_results_raceId]
GO

