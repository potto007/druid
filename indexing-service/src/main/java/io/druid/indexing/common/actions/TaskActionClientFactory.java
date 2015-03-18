/*
 * Druid - a distributed column store.
 * Copyright 2012 - 2015 Metamarkets Group Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.druid.indexing.common.actions;

import io.druid.indexing.common.task.Task;

/**
 */
public interface TaskActionClientFactory
{
  public TaskActionClient create(Task task);
  /**
   * Remote tasks use central coordination for handoff to deep storage through the overlord.
   * @return true if the task should use central overlord coordination.
   */
  public Boolean isRemote();
}
